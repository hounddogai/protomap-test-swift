import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan profiles through their life cycle and keeps a journal of what it did.
    final class AcuityPlanProfileDesk {
        var store: any AcuityPlanProfileStore
        var validator: AcuityPlanProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AcuityPlanProfileStore, validator: AcuityPlanProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanProfileStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanProfileStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAcuityPlanProfileDesk(_ store: any AcuityPlanProfileStore, clock: any Kit.Clocks.Clock) -> AcuityPlanProfileDesk {
        return AcuityPlanProfileDesk(
            store: store,
            validator: defaultAcuityPlanProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
