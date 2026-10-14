@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryOvertimePreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.OvertimePreferenceStore = Staffing.newMemoryOvertimePreferenceStore()
        let item = Staffing.newOvertimePreference("code-719", title: "title-69")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
