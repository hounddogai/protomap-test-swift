@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolBaselineStore = Imaging.newMemoryCareProtocolBaselineStore()
        let item = Imaging.newCareProtocolBaseline("code-89", name: "name-921")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
