import AcmePlatform
import Foundation

extension Staffing {
    /// Moves legacy shift exceptions through their life cycle and keeps a journal of what it did.
    final class LegacyShiftExceptionCoordinator {
        var store: any LegacyShiftExceptionStore
        var validator: LegacyShiftExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyShiftExceptionEngine

        init(store: any LegacyShiftExceptionStore, validator: LegacyShiftExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyShiftExceptionEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy shift exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyShiftExceptionStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy shift exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyShiftExceptionStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy shift exception \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newLegacyShiftExceptionCoordinator(_ store: any LegacyShiftExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyShiftExceptionCoordinator {
        return LegacyShiftExceptionCoordinator(
            store: store,
            validator: defaultLegacyShiftExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyShiftExceptionEngine(flags)
        )
    }
}
