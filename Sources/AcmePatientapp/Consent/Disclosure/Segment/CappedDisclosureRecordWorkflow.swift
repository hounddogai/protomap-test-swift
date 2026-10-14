import AcmePlatform
import Foundation

extension Consent {
    /// Moves capped disclosure records through their life cycle and keeps a journal of what it did.
    final class CappedDisclosureRecordCoordinator {
        var store: any CappedDisclosureRecordStore
        var validator: CappedDisclosureRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedDisclosureRecordEngine

        init(store: any CappedDisclosureRecordStore, validator: CappedDisclosureRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedDisclosureRecordEngine) {
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
                throw Kit.Failure("capped disclosure record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedDisclosureRecordStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped disclosure record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedDisclosureRecordStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped disclosure record \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newCappedDisclosureRecordCoordinator(_ store: any CappedDisclosureRecordStore, clock: any Kit.Clocks.Clock) -> CappedDisclosureRecordCoordinator {
        return CappedDisclosureRecordCoordinator(
            store: store,
            validator: defaultCappedDisclosureRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedDisclosureRecordEngine()
        )
    }
}
