@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictOvertimeAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictOvertimeAgreementStore = Staffing.newMemoryStrictOvertimeAgreementStore()
        let item = Staffing.newStrictOvertimeAgreement("code-814", title: "title-98")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
