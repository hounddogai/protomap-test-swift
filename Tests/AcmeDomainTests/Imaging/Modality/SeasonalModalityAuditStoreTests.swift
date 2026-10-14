@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalModalityAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalModalityAuditStore = Imaging.newMemorySeasonalModalityAuditStore()
        let item = Imaging.newSeasonalModalityAudit("code-483", title: "title-875")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
