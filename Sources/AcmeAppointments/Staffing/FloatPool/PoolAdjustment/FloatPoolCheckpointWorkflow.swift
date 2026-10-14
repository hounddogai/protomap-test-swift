import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool checkpoints through their life cycle and keeps a journal of what it did.
    final class FloatPoolCheckpointService {
        var store: any FloatPoolCheckpointStore
        var validator: FloatPoolCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolCheckpointEngine

        init(store: any FloatPoolCheckpointStore, validator: FloatPoolCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolCheckpointEngine) {
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
                throw Kit.Failure("float pool checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolCheckpointStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolCheckpointStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool checkpoint \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newFloatPoolCheckpointService(_ store: any FloatPoolCheckpointStore, clock: any Kit.Clocks.Clock) -> FloatPoolCheckpointService {
        return FloatPoolCheckpointService(
            store: store,
            validator: defaultFloatPoolCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolCheckpointEngine()
        )
    }
}
