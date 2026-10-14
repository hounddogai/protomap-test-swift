@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryWeightedTransferAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.WeightedTransferAgreementStore = BedManagement.newMemoryWeightedTransferAgreementStore()
        let item = BedManagement.newWeightedTransferAgreement("code-307", title: "title-232")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
