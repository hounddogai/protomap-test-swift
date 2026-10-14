import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool allocations through their life cycle and keeps a journal of what it did.
    final class FloatPoolAllocationDesk {
        var store: any FloatPoolAllocationStore
        var validator: FloatPoolAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolAllocationEngine

        init(store: any FloatPoolAllocationStore, validator: FloatPoolAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolAllocationEngine) {
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
                throw Kit.Failure("float pool allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolAllocationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolAllocationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool allocation \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newFloatPoolAllocationDesk(_ store: any FloatPoolAllocationStore, clock: any Kit.Clocks.Clock) -> FloatPoolAllocationDesk {
        return FloatPoolAllocationDesk(
            store: store,
            validator: defaultFloatPoolAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolAllocationEngine()
        )
    }
}
