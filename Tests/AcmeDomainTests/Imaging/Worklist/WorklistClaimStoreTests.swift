@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistClaimStore = Imaging.newMemoryWorklistClaimStore()
        let item = Imaging.newWorklistClaim("code-618", name: "name-527")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
