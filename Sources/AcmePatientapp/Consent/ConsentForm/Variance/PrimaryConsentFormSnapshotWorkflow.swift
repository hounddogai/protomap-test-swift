import AcmePlatform
import Foundation

extension Consent {
    /// Moves primary consent form snapshots through their life cycle and keeps a journal of what it did.
    final class PrimaryConsentFormSnapshotService {
        var store: any PrimaryConsentFormSnapshotStore
        var validator: PrimaryConsentFormSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryConsentFormSnapshotEngine

        init(store: any PrimaryConsentFormSnapshotStore, validator: PrimaryConsentFormSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryConsentFormSnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary consent form snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryConsentFormSnapshotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary consent form snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryConsentFormSnapshotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary consent form snapshot \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPrimaryConsentFormSnapshotService(_ store: any PrimaryConsentFormSnapshotStore, clock: any Kit.Clocks.Clock) -> PrimaryConsentFormSnapshotService {
        return PrimaryConsentFormSnapshotService(
            store: store,
            validator: defaultPrimaryConsentFormSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryConsentFormSnapshotEngine()
        )
    }
}
