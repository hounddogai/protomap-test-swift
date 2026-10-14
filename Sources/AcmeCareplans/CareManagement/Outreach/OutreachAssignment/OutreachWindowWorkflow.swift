import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach windows through their life cycle and keeps a journal of what it did.
    final class OutreachWindowService {
        var store: any OutreachWindowStore
        var validator: OutreachWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OutreachWindowStore, validator: OutreachWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("outreach window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachWindowStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachWindowStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newOutreachWindowService(_ store: any OutreachWindowStore, clock: any Kit.Clocks.Clock) -> OutreachWindowService {
        return OutreachWindowService(
            store: store,
            validator: defaultOutreachWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
