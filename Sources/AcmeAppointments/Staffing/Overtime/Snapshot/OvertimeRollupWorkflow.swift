import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime rollups through their life cycle and keeps a journal of what it did.
    final class OvertimeRollupCoordinator {
        var store: any OvertimeRollupStore
        var validator: OvertimeRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeRollupEngine

        init(store: any OvertimeRollupStore, validator: OvertimeRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeRollupEngine) {
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
                throw Kit.Failure("overtime rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeRollupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeRollupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime rollup \(code) not found")
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

    static func newOvertimeRollupCoordinator(_ store: any OvertimeRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OvertimeRollupCoordinator {
        return OvertimeRollupCoordinator(
            store: store,
            validator: defaultOvertimeRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeRollupEngine(flags)
        )
    }
}
