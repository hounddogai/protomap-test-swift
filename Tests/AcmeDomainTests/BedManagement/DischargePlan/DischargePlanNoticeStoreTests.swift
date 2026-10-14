@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryDischargePlanNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.DischargePlanNoticeStore = BedManagement.newMemoryDischargePlanNoticeStore()
        let item = BedManagement.newDischargePlanNotice("code-9", name: "name-933")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
