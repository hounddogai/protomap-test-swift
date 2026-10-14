@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryShiftAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ShiftAgreementStore = Staffing.newMemoryShiftAgreementStore()
        let item = Staffing.newShiftAgreement("code-549", name: "name-4")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
