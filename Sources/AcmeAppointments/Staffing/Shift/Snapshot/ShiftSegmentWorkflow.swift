import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift segments through their life cycle and keeps a journal of what it did.
    final class ShiftSegmentManager {
        var store: any ShiftSegmentStore
        var validator: ShiftSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftSegmentEngine

        init(store: any ShiftSegmentStore, validator: ShiftSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftSegmentEngine) {
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
                throw Kit.Failure("shift segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftSegmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftSegmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift segment \(code) not found")
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

    static func newShiftSegmentManager(_ store: any ShiftSegmentStore, clock: any Kit.Clocks.Clock) -> ShiftSegmentManager {
        return ShiftSegmentManager(
            store: store,
            validator: defaultShiftSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftSegmentEngine()
        )
    }
}
