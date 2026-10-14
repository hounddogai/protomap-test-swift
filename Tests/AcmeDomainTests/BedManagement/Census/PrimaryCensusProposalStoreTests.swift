@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryPrimaryCensusProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.PrimaryCensusProposalStore = BedManagement.newMemoryPrimaryCensusProposalStore()
        let item = BedManagement.newPrimaryCensusProposal("code-651", title: "title-904")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
