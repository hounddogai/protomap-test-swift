@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBatchedTransferClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BatchedTransferClaimStore = BedManagement.newMemoryBatchedTransferClaimStore()
        let item = BedManagement.newBatchedTransferClaim("code-244", name: "name-119")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
