@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRollingShiftNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RollingShiftNoticeStore = Staffing.newMemoryRollingShiftNoticeStore()
        let item = Staffing.newRollingShiftNotice("code-867", label: "label-426")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
