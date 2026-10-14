@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAssessmentProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AssessmentProposalStore = CareManagement.newMemoryAssessmentProposalStore()
        let item = CareManagement.newAssessmentProposal("code-683", title: "title-104")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
