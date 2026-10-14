@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningNoticeStore = BedManagement.newMemoryCleaningNoticeStore()
        let item = BedManagement.newCleaningNotice("code-698", label: "label-747")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
