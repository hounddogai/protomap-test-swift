@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveProgramExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveProgramExceptionStore = CareManagement.newMemoryAdaptiveProgramExceptionStore()
        let item = CareManagement.newAdaptiveProgramException("code-704", title: "title-871")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
