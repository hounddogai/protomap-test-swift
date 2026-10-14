@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferProposalStore = BedManagement.newMemoryTransferProposalStore()
        let item = BedManagement.newTransferProposal("code-402", label: "label-94")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
