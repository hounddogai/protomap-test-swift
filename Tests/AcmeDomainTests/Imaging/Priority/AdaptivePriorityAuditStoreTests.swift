@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptivePriorityAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptivePriorityAuditStore = Imaging.newMemoryAdaptivePriorityAuditStore()
        let item = Imaging.newAdaptivePriorityAudit("code-54", name: "name-128")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
