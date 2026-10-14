import AcmePlatform
import Foundation

extension Consent {
    /// Moves manual proxy schedules through their life cycle and keeps a journal of what it did.
    final class ManualProxyScheduleService {
        var store: any ManualProxyScheduleStore
        var validator: ManualProxyScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualProxyScheduleEngine

        init(store: any ManualProxyScheduleStore, validator: ManualProxyScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualProxyScheduleEngine) {
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
                throw Kit.Failure("manual proxy schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualProxyScheduleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual proxy schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualProxyScheduleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual proxy schedule \(code) not found")
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

    static func newManualProxyScheduleService(_ store: any ManualProxyScheduleStore, clock: any Kit.Clocks.Clock) -> ManualProxyScheduleService {
        return ManualProxyScheduleService(
            store: store,
            validator: defaultManualProxyScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualProxyScheduleEngine()
        )
    }
}
