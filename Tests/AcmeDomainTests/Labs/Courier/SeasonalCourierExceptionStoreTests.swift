@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalCourierExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalCourierExceptionStore = Labs.newMemorySeasonalCourierExceptionStore()
        let item = Labs.newSeasonalCourierException("code-126", title: "title-295")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
