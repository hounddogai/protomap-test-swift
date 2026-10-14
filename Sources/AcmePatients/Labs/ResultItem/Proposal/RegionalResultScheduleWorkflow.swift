import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional result schedules through their life cycle and keeps a journal of what it did.
    final class RegionalResultScheduleCoordinator {
        var store: any RegionalResultScheduleStore
        var validator: RegionalResultScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalResultScheduleEngine

        init(store: any RegionalResultScheduleStore, validator: RegionalResultScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalResultScheduleEngine) {
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
                throw Kit.Failure("regional result schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalResultScheduleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional result schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalResultScheduleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional result schedule \(code) not found")
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

    static func newRegionalResultScheduleCoordinator(_ store: any RegionalResultScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalResultScheduleCoordinator {
        return RegionalResultScheduleCoordinator(
            store: store,
            validator: defaultRegionalResultScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalResultScheduleEngine(flags)
        )
    }
}
