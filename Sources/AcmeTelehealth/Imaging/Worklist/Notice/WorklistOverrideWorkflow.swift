import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist overrides through their life cycle and keeps a journal of what it did.
    final class WorklistOverrideService {
        var store: any WorklistOverrideStore
        var validator: WorklistOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistOverrideEngine

        init(store: any WorklistOverrideStore, validator: WorklistOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistOverrideEngine) {
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
                throw Kit.Failure("worklist override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistOverrideStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistOverrideStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist override \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newWorklistOverrideService(_ store: any WorklistOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WorklistOverrideService {
        return WorklistOverrideService(
            store: store,
            validator: defaultWorklistOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistOverrideEngine(flags)
        )
    }
}
