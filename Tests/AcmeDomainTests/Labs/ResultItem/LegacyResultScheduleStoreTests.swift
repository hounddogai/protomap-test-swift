@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyResultScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyResultScheduleStore = Labs.newMemoryLegacyResultScheduleStore()
        let item = Labs.newLegacyResultSchedule("code-415", title: "title-547")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
