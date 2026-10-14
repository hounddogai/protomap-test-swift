import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending proxy schedules through their life cycle and keeps a journal of what it did.
    final class PendingProxyScheduleWorkflow {
        var store: any PendingProxyScheduleStore
        var validator: PendingProxyScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingProxyScheduleEngine

        init(store: any PendingProxyScheduleStore, validator: PendingProxyScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingProxyScheduleEngine) {
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
                throw Kit.Failure("pending proxy schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingProxyScheduleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending proxy schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingProxyScheduleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending proxy schedule \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPendingProxyScheduleWorkflow(_ store: any PendingProxyScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingProxyScheduleWorkflow {
        return PendingProxyScheduleWorkflow(
            store: store,
            validator: defaultPendingProxyScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingProxyScheduleEngine(flags)
        )
    }
}
