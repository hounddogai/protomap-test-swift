@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingAlertProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingAlertProposalStore = ClinicalOps.newMemoryRollingAlertProposalStore()
        let item = ClinicalOps.newRollingAlertProposal("code-312", title: "title-522")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
