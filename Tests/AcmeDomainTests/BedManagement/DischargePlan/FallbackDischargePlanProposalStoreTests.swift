@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryFallbackDischargePlanProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.FallbackDischargePlanProposalStore = BedManagement.newMemoryFallbackDischargePlanProposalStore()
        let item = BedManagement.newFallbackDischargePlanProposal("code-572", name: "name-599")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
