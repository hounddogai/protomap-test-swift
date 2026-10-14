@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryAdaptiveCleaningNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.AdaptiveCleaningNoticeStore = BedManagement.newMemoryAdaptiveCleaningNoticeStore()
        let item = BedManagement.newAdaptiveCleaningNotice("code-494", title: "title-211")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
