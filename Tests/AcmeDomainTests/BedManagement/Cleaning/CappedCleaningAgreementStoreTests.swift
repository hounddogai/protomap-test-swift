@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCappedCleaningAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CappedCleaningAgreementStore = BedManagement.newMemoryCappedCleaningAgreementStore()
        let item = BedManagement.newCappedCleaningAgreement("code-120", label: "label-633")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
