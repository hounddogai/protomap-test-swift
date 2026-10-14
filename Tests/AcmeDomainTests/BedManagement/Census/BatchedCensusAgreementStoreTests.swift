@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBatchedCensusAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BatchedCensusAgreementStore = BedManagement.newMemoryBatchedCensusAgreementStore()
        let item = BedManagement.newBatchedCensusAgreement("code-956", name: "name-599")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
