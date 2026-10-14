import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range entries through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeEntryService {
        var store: any ReferenceRangeEntryStore
        var validator: ReferenceRangeEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferenceRangeEntryEngine

        init(store: any ReferenceRangeEntryStore, validator: ReferenceRangeEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferenceRangeEntryEngine) {
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
                throw Kit.Failure("reference range entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeEntryStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeEntryStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range entry \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newReferenceRangeEntryService(_ store: any ReferenceRangeEntryStore, clock: any Kit.Clocks.Clock) -> ReferenceRangeEntryService {
        return ReferenceRangeEntryService(
            store: store,
            validator: defaultReferenceRangeEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferenceRangeEntryEngine()
        )
    }
}
