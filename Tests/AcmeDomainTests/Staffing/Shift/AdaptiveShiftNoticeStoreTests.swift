@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryAdaptiveShiftNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.AdaptiveShiftNoticeStore = Staffing.newMemoryAdaptiveShiftNoticeStore()
        let item = Staffing.newAdaptiveShiftNotice("code-810", title: "title-996")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
