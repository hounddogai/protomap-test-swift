@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBedBoardAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BedBoardAgreementStore = BedManagement.newMemoryBedBoardAgreementStore()
        let item = BedManagement.newBedBoardAgreement("code-806", label: "label-583")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
