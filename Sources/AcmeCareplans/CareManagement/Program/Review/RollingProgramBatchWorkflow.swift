import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves rolling program batches through their life cycle and keeps a journal of what it did.
    final class RollingProgramBatchCoordinator {
        var store: any RollingProgramBatchStore
        var validator: RollingProgramBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingProgramBatchEngine

        init(store: any RollingProgramBatchStore, validator: RollingProgramBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingProgramBatchEngine) {
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
                throw Kit.Failure("rolling program batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingProgramBatchStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling program batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingProgramBatchStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling program batch \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRollingProgramBatchCoordinator(_ store: any RollingProgramBatchStore, clock: any Kit.Clocks.Clock) -> RollingProgramBatchCoordinator {
        return RollingProgramBatchCoordinator(
            store: store,
            validator: defaultRollingProgramBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingProgramBatchEngine()
        )
    }
}
