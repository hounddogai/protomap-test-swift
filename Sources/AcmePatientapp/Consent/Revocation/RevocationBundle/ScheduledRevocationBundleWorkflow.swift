import AcmePlatform
import Foundation

extension Consent {
    /// Moves scheduled revocation bundles through their life cycle and keeps a journal of what it did.
    final class ScheduledRevocationBundleManager {
        var store: any ScheduledRevocationBundleStore
        var validator: ScheduledRevocationBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledRevocationBundleEngine

        init(store: any ScheduledRevocationBundleStore, validator: ScheduledRevocationBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledRevocationBundleEngine) {
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
                throw Kit.Failure("scheduled revocation bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledRevocationBundleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled revocation bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledRevocationBundleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled revocation bundle \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newScheduledRevocationBundleManager(_ store: any ScheduledRevocationBundleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledRevocationBundleManager {
        return ScheduledRevocationBundleManager(
            store: store,
            validator: defaultScheduledRevocationBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledRevocationBundleEngine(flags)
        )
    }
}
