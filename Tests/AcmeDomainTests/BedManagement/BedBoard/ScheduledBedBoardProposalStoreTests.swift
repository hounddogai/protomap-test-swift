@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryScheduledBedBoardProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.ScheduledBedBoardProposalStore = BedManagement.newMemoryScheduledBedBoardProposalStore()
        let item = BedManagement.newScheduledBedBoardProposal("code-99", label: "label-989")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
