import AcmePlatform
import Foundation

extension Staffing {
    /// Moves rolling overtime segments through their life cycle and keeps a journal of what it did.
    final class RollingOvertimeSegmentService {
        var store: any RollingOvertimeSegmentStore
        var validator: RollingOvertimeSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingOvertimeSegmentEngine

        init(store: any RollingOvertimeSegmentStore, validator: RollingOvertimeSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingOvertimeSegmentEngine) {
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
                throw Kit.Failure("rolling overtime segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingOvertimeSegmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling overtime segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingOvertimeSegmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling overtime segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRollingOvertimeSegmentService(_ store: any RollingOvertimeSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingOvertimeSegmentService {
        return RollingOvertimeSegmentService(
            store: store,
            validator: defaultRollingOvertimeSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingOvertimeSegmentEngine(flags)
        )
    }
}
