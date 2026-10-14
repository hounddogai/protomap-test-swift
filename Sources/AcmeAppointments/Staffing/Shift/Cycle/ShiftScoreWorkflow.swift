import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift scores through their life cycle and keeps a journal of what it did.
    final class ShiftScoreManager {
        var store: any ShiftScoreStore
        var validator: ShiftScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftScoreEngine

        init(store: any ShiftScoreStore, validator: ShiftScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftScoreEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftScoreStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftScoreStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift score \(code) not found")
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

    static func newShiftScoreManager(_ store: any ShiftScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ShiftScoreManager {
        return ShiftScoreManager(
            store: store,
            validator: defaultShiftScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftScoreEngine(flags)
        )
    }
}
