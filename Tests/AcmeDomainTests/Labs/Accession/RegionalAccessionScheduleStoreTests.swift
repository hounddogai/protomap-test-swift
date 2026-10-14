@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalAccessionScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalAccessionScheduleStore = Labs.newMemoryRegionalAccessionScheduleStore()
        let item = Labs.newRegionalAccessionSchedule("code-559", title: "title-561")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
