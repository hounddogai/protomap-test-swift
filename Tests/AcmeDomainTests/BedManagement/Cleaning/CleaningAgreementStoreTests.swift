@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningAgreementStore = BedManagement.newMemoryCleaningAgreementStore()
        let item = BedManagement.newCleaningAgreement("code-164", name: "name-185")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
