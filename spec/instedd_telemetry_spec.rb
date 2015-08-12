require 'spec_helper'

describe InsteddTelemetry do

  describe "sets" do

    it "creates set occurrences on set_add for each distinct key attribute set" do
      expect{
        InsteddTelemetry.set_add(:channels, {project_id: 1}, :smpp)
        InsteddTelemetry.set_add(:channels, {project_id: 2}, :smpp)
      }.to change(InsteddTelemetry::SetOccurrence, :count).by(2)
    end

    it "exposes parsed key attributes after retrieving from database" do
      InsteddTelemetry.set_add(:channels, {project_id: 3}, :smpp)
      occurrence = InsteddTelemetry::SetOccurrence.first
      expect(occurrence.key_attributes).to eq({"project_id" => 3})
    end

    it "does not create new occurrence if element was present" do
      InsteddTelemetry.set_add(:channels, {project_id: 3}, :smpp)

      expect{
        InsteddTelemetry.set_add(:channels, {project_id: 3}, :smpp)
      }.not_to change(InsteddTelemetry::SetOccurrence, :count)
    end

    it "uses normalized attributes to identify set keys" do
      InsteddTelemetry.set_add(:channels, {project_id: 3, other_attribute: :ok}, :smpp)

      expect{
        InsteddTelemetry.set_add(:channels, {other_attribute: :ok, project_id: 3}, :smpp)
        InsteddTelemetry.set_add(:channels, {"project_id" => 3, "other_attribute" => :ok}, :smpp)
        InsteddTelemetry.set_add(:channels, {project_id: 3, other_attribute: "ok"}, :smpp)
      }.not_to change(InsteddTelemetry::SetOccurrence, :count)
    end

    it "creates new occurrences when new element is added to pre-existing key" do
      InsteddTelemetry.set_add(:channels, {project_id: 3}, :smpp)
      InsteddTelemetry.set_add(:channels, {project_id: 3}, :other)

      expect(InsteddTelemetry::SetOccurrence.count).to eq(2)
    end

  end

  describe "counters" do

    it "stores counter after first add" do
      expect{
        InsteddTelemetry.counter_add(:calls, {project_id: 1})
        InsteddTelemetry.counter_add(:calls, {project_id: 2})
      }.to change(InsteddTelemetry::Counter, :count).by(2)
    end

    it "initializes counters correctly" do
      InsteddTelemetry.counter_add(:calls, {project_id: 1})
      expect(InsteddTelemetry::Counter.first.count).to eq(1)
    end

    it "increments counters according to specified amount" do
      InsteddTelemetry.counter_add(:calls, {project_id: 1})
      InsteddTelemetry.counter_add(:calls, {project_id: 2})

      c1 = InsteddTelemetry::Counter.first
      c2 = InsteddTelemetry::Counter.last

      InsteddTelemetry.counter_add(:calls, {project_id: 1})

      expect(c1.reload.count).to eq(2)
      expect(c2.reload.count).to eq(1)

      InsteddTelemetry.counter_add(:calls, {project_id: 1}, 2)
      InsteddTelemetry.counter_add(:calls, {project_id: 2}, 10)

      expect(c1.reload.count).to eq(4)
      expect(c2.reload.count).to eq(11)
    end

  end

end