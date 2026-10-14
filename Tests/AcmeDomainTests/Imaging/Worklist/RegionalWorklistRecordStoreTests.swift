@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalWorklistRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalWorklistRecordStore = Imaging.newMemoryRegionalWorklistRecordStore()
        let item = Imaging.newRegionalWorklistRecord("code-25", label: "label-134")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
