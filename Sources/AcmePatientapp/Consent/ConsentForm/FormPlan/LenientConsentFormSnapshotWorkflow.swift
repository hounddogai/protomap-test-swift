import AcmePlatform
import Foundation

extension Consent {
    /// Moves lenient consent form snapshots through their life cycle and keeps a journal of what it did.
    final class LenientConsentFormSnapshotManager {
        var store: any LenientConsentFormSnapshotStore
        var validator: LenientConsentFormSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientConsentFormSnapshotEngine

        init(store: any LenientConsentFormSnapshotStore, validator: LenientConsentFormSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientConsentFormSnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient consent form snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientConsentFormSnapshotStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient consent form snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientConsentFormSnapshotStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient consent form snapshot \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newLenientConsentFormSnapshotManager(_ store: any LenientConsentFormSnapshotStore, clock: any Kit.Clocks.Clock) -> LenientConsentFormSnapshotManager {
        return LenientConsentFormSnapshotManager(
            store: store,
            validator: defaultLenientConsentFormSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientConsentFormSnapshotEngine()
        )
    }
}
