import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import SwiftProtobuf
import Testing

@Test func protobufEnvelopesPreserveNestedMapsAndOneofs() throws {
    let record = Acme_Patients_V1_MedicalRecord.with {
        $0.medicalRecordID = "record-17"
        $0.metadata = ["source": "clinic", "locale": "fr"]
        $0.card = .with {
            $0.token = "synthetic-token"
            $0.holderName = "Avery"
        }
        $0.lines = [
            .with {
                $0.sku = "visit"
                $0.quantity = 2
            }
        ]
    }
    let decoded = try Projection.json(record)
    let unpacked = try Projection.unpack(record)
    #expect(decoded == record)
    #expect(unpacked == record)
    #expect(Projection.read(record, at: \Acme_Patients_V1_MedicalRecord.card.token) == "synthetic-token")
    let enriched = Projection.updating(record) { $0.card.holderName = "Blair" }
    #expect(enriched.card.token == "synthetic-token")
    #expect(enriched.card.holderName == "Blair")
    #expect(enriched.metadata == record.metadata)
}

@Test func taskGroupRestoresOrderAndPropagatesFailure() async throws {
    let result = try await FanOut.map([3, 2, 1]) { value in
        try await Task.sleep(for: .milliseconds(value))
        return value * 2
    }
    #expect(result == [6, 4, 2])
    do {
        _ = try await FanOut.map([1, 2, 3]) { value in
            if value == 2 { throw RPCError(code: .aborted, message: "Interrupted") }
            return value
        }
        Issue.record("A failed child must fail the fan-out")
    } catch let error as RPCError {
        #expect(error.code == .aborted)
    }
}

@Test func sqliteWritesAreTenantScopedAndUpsertRecords() async throws {
    let repository = try SQLiteRepository(path: ":memory:")
    let record = StoredRecord(tenant: "clinic-a", kind: "patient", recordID: "17", body: Data([1, 2]))
    try await repository.save(record)
    try await repository.save(record)
    try await repository.recordAction(tenant: "clinic-a", kind: "patient", action: "review", detail: "checked")
    #expect(try await repository.count(tenant: "clinic-a") == 1)
    #expect(try await repository.count(tenant: "clinic-b") == 0)
}

@Test func backgroundQueueReportsOverflowAndFinishes() async throws {
    let queue = WorkQueue<Int>(capacity: 1)
    try queue.submit(1)
    do {
        try queue.submit(2)
        Issue.record("A full queue must reject new work")
    } catch let error as RPCError {
        #expect(error.code == .resourceExhausted)
    }
    queue.finish()
    var values: [Int] = []
    for await value in queue.events { values.append(value) }
    #expect(values == [1])
}
