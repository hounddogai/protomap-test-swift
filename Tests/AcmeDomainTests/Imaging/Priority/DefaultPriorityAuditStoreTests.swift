@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryDefaultPriorityAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.DefaultPriorityAuditStore = Imaging.newMemoryDefaultPriorityAuditStore()
        let item = Imaging.newDefaultPriorityAudit("code-148", name: "name-288")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
