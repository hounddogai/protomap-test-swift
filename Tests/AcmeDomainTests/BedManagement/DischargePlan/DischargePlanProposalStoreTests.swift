@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanProposalStore = BedManagement.newMemoryDischargePlanProposalStore()
        let item = BedManagement.newDischargePlanProposal("code-921", label: "label-492")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
