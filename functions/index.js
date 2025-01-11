const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendThiefNotification = functions.database
    .ref("/11110000t/thief")
    .onUpdate((change, context) => {
      const beforeValue = change.before.val();
      const afterValue = change.after.val();

      // Check if the value changed to "yes"
      if (beforeValue !== "yes" && afterValue === "yes") {
        const payload = {
          notification: {
            title: "Thief Alert!",
            body: "A potential theft attempt was detected.",
          },
        };

        // Replace with your FCM topic or user's device token
        const topic = "user_notifications";

        return admin.messaging().sendToTopic(topic, payload)
            .then((response) => {
              console.log("Notification sent successfully:", response);
            })
            .catch((error) => {
              console.error("Error sending notification:", error);
            });
      }

      return null;
    });
