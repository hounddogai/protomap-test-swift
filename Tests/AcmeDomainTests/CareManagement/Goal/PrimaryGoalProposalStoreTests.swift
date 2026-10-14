@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPrimaryGoalProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PrimaryGoalProposalStore = CareManagement.newMemoryPrimaryGoalProposalStore()
        let item = CareManagement.newPrimaryGoalProposal("code-93", label: "label-701")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
