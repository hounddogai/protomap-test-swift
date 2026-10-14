@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingRecallProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingRecallProposalStore = Pharmacy.newMemoryRollingRecallProposalStore()
        let item = Pharmacy.newRollingRecallProposal("code-146", label: "label-719")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
